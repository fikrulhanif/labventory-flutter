<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Append-only audit trail for loan status transitions.
 *
 * @property int    $id
 * @property int    $loan_id
 * @property int    $actor_user_id
 * @property string $from_status
 * @property string $to_status
 * @property string|null $note
 * @property \Illuminate\Support\Carbon $created_at
 */
class LoanStatusHistory extends Model
{
    protected $table = 'loan_status_history';

    /**
     * This table only records insert events; no updated_at column.
     */
    public $timestamps = false;

    /** @var list<string> */
    protected $fillable = [
        'loan_id',
        'actor_user_id',
        'from_status',
        'to_status',
        'note',
        'created_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Loan, $this>
     */
    public function loan(): BelongsTo
    {
        return $this->belongsTo(Loan::class);
    }

    /**
     * The user who performed the transition (admin or laboran).
     *
     * @return BelongsTo<User, $this>
     */
    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }
}
