<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Notification center table.
 *
 * Stores in-app notifications for students (and optionally staff).
 * This is NOT a push-notification table — records are polled via REST
 * API on demand. The Flutter app calls GET /api/notifications to list
 * and GET /api/notifications/unread-count for the badge count.
 */
return new class () extends Migration {
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnUpdate()
                ->cascadeOnDelete(); // Remove notifications when user is deleted

            $table->string('title');
            $table->text('message');

            // Discriminator used by the Flutter client to pick an icon/colour
            // and by analytics. Allowed values defined in AppNotification::TYPE_*.
            $table->string('type', 32)->default('system')->index();

            // Optional reference to the related loan; nullable so system
            // notifications don't require a loan.
            $table->foreignId('loan_id')
                ->nullable()
                ->constrained('loans')
                ->nullOnDelete(); // Keep notification if loan is deleted

            $table->boolean('is_read')->default(false)->index();

            $table->timestamps();

            // Fast lookup: all unread notifications for a user, newest-first.
            $table->index(['user_id', 'is_read', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
