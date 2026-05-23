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
        Schema::create('loan_status_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('loan_id')
                ->constrained('loans')
                ->cascadeOnUpdate()
                ->cascadeOnDelete();
            $table->foreignId('actor_user_id')
                ->constrained('users')
                ->cascadeOnUpdate()
                ->restrictOnDelete();
            $table->enum('from_status', [
                'pending',
                'approved',
                'rejected',
                'borrowed',
                'returned',
            ]);
            $table->enum('to_status', [
                'pending',
                'approved',
                'rejected',
                'borrowed',
                'returned',
            ]);
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['loan_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('loan_status_history');
    }
};
