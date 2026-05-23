<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * @property int    $id
 * @property string $name
 * @property string|null $nim
 * @property string $email
 * @property string $password
 * @property string $role    one of "admin", "laboran", "student"
 * @property string $status  one of "active", "inactive"
 */
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens;
    use HasFactory;
    use Notifiable;

    public const ROLE_ADMIN = 'admin';

    public const ROLE_LABORAN = 'laboran';

    public const ROLE_STUDENT = 'student';

    public const STATUS_ACTIVE = 'active';

    public const STATUS_INACTIVE = 'inactive';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'nim',
        'email',
        'password',
        'role',
        'status',
    ];

    /**
     * The attributes hidden from arrays / JSON serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Casts.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // ---------- Relationships ----------

    /**
     * Loans placed by this user (only meaningful for students).
     *
     * @return HasMany<Loan>
     */
    public function loans(): HasMany
    {
        return $this->hasMany(Loan::class);
    }

    // ---------- Role / status helpers ----------

    public function isAdmin(): bool
    {
        return $this->role === self::ROLE_ADMIN;
    }

    public function isLaboran(): bool
    {
        return $this->role === self::ROLE_LABORAN;
    }

    public function isStudent(): bool
    {
        return $this->role === self::ROLE_STUDENT;
    }

    /**
     * Either admin or laboran — both have access to the admin dashboard.
     */
    public function isStaff(): bool
    {
        return $this->isAdmin() || $this->isLaboran();
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }
}
