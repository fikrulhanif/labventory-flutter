<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('loans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnUpdate()
                ->restrictOnDelete();
            $table->foreignId('inventory_id')
                ->constrained('inventories')
                ->cascadeOnUpdate()
                ->restrictOnDelete();
            $table->date('borrow_date');
            $table->date('return_date');
            $table->enum('status', [
                'pending',
                'approved',
                'rejected',
                'borrowed',
                'returned',
            ])->default('pending')->index();
            $table->string('document');
            $table->text('notes')->nullable();
            $table->timestamp('picked_up_at')->nullable();
            $table->timestamp('returned_at')->nullable();
            $table->text('reject_reason')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['inventory_id', 'status']);
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('loans');
    }
};
