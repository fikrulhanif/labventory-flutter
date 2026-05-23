<?php

namespace App\Models;

use Database\Factories\LoanFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property int $user_id
 * @property int $inventory_id
 * @property \Illuminate\Support\Carbon $borrow_date
 * @property \Illuminate\Support\Carbon $return_date
 * @property string $status         one of pending|approved|rejected|borrowed|returned
 * @property string $document       relative path on the public disk (KTM)
 * @property string|null $notes
 * @property \Illuminate\Support\Carbon|null $picked_up_at
 * @property \Illuminate\Support\Carbon|null $returned_at
 * @property string|null $reject_reason
 */
class Loan extends Model
{
    /** @use HasFactory<LoanFactory> */
    use HasFactory;

    public const STATUS_PENDING = 'pending';

    public const STATUS_APPROVED = 'approved';

    public const STATUS_REJECTED = 'rejected';

    public const STATUS_BORROWED = 'borrowed';

    public const STATUS_RETURNED = 'returned';

    /** @var list<string> */
    public const ALL_STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_APPROVED,
        self::STATUS_REJECTED,
        self::STATUS_BORROWED,
        self::STATUS_RETURNED,
    ];

    /** @var list<string> */
    protected $fillable = [
        'user_id',
        'inventory_id',
        'borrow_date',
        'return_date',
        'status',
        'document',
        'notes',
        'picked_up_at',
        'returned_at',
        'reject_reason',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'borrow_date' => 'date',
            'return_date' => 'date',
            'picked_up_at' => 'datetime',
            'returned_at' => 'datetime',
        ];
    }

    // ---------- Relationships ----------

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<Inventory, $this>
     */
    public function inventory(): BelongsTo
    {
        return $this->belongsTo(Inventory::class);
    }

    /**
     * Audit trail of every status transition for this loan.
     *
     * @return HasMany<LoanStatusHistory>
     */
    public function statusHistory(): HasMany
    {
        return $this->hasMany(LoanStatusHistory::class);
    }

    // ---------- Scopes ----------

    /**
     * @param  Builder<Loan>  $query
     * @return Builder<Loan>
     */
    public function scopeForUser(Builder $query, int $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    /**
     * @param  Builder<Loan>  $query
     * @return Builder<Loan>
     */
    public function scopeWithStatus(Builder $query, string $status): Builder
    {
        return $query->where('status', $status);
    }
}
