<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * In-app notification record.
 *
 * Named AppNotification (not Notification) to avoid clashing with
 * Laravel's own \Illuminate\Notifications\Notification base class.
 *
 * @property int $id
 * @property int $user_id
 * @property string $title
 * @property string $message
 * @property string $type  one of the TYPE_* constants
 * @property int|null $loan_id
 * @property bool $is_read
 * @property \Illuminate\Support\Carbon $created_at
 * @property \Illuminate\Support\Carbon $updated_at
 */
class AppNotification extends Model
{
    protected $table = 'notifications';

    // ---- Type constants ----
    public const TYPE_LOAN_CREATED  = 'loan_created';
    public const TYPE_LOAN_APPROVED = 'loan_approved';
    public const TYPE_LOAN_REJECTED = 'loan_rejected';
    public const TYPE_LOAN_BORROWED = 'loan_borrowed';
    public const TYPE_LOAN_RETURNED = 'loan_returned';
    public const TYPE_SYSTEM        = 'system';

    /** @var list<string> */
    protected $fillable = [
        'user_id',
        'title',
        'message',
        'type',
        'loan_id',
        'is_read',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_read' => 'boolean',
        ];
    }

    // ---- Relationships ----

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<Loan, $this>
     */
    public function loan(): BelongsTo
    {
        return $this->belongsTo(Loan::class);
    }
}
