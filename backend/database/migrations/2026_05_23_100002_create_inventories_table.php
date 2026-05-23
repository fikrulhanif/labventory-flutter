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
        Schema::create('inventories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')
                ->constrained('categories')
                ->cascadeOnUpdate()
                ->restrictOnDelete();
            $table->string('name');
            $table->string('code')->unique();
            $table->unsignedInteger('stock')->default(0);
            $table->text('description')->nullable();
            $table->string('image')->nullable();
            $table->string('qr_code')->nullable();
            $table->enum('status', ['available', 'out_of_stock'])->default('out_of_stock')->index();
            $table->timestamps();

            $table->index('name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('inventories');
    }
};
