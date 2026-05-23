<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Audit row inserted on every failed mobile login attempt
 * (unknown NIM, wrong password, or inactive account).
 *
 * @property int    $id
 * @property string $nim
 * @property string|null $ip
 * @property \Illuminate\Support\Carbon $created_at
 */
class FailedLogin extends Model
{
    /**
     * Insert-only audit table; no updated_at column exists.
     */
    public $timestamps = false;

    /** @var list<string> */
    protected $fillable = [
        'nim',
        'ip',
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
}
