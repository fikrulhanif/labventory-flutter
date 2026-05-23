<?php

namespace App\Models;

use Database\Factories\InventoryFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

/**
 * @property int    $id
 * @property int    $category_id
 * @property string $name
 * @property string $code
 * @property int    $stock
 * @property string|null $description
 * @property string|null $image    relative path on the public disk (e.g. "inventories/abc.jpg")
 * @property string|null $qr_code  relative path on the public disk (e.g. "qr/INV-001-xyz.png")
 * @property string $status        one of "available", "out_of_stock"
 *
 * @property-read string|null $image_url
 * @property-read string|null $qr_url
 */
class Inventory extends Model
{
    /** @use HasFactory<InventoryFactory> */
    use HasFactory;

    public const STATUS_AVAILABLE = 'available';

    public const STATUS_OUT_OF_STOCK = 'out_of_stock';

    /**
     * Loan statuses that count an inventory item as "in active use".
     * Used by the delete guard and the stock-conservation invariant.
     *
     * @var list<string>
     */
    public const ACTIVE_LOAN_STATUSES = [
        Loan::STATUS_PENDING,
        Loan::STATUS_APPROVED,
        Loan::STATUS_BORROWED,
    ];

    /** @var list<string> */
    protected $fillable = [
        'category_id',
        'name',
        'code',
        'stock',
        'description',
        'image',
        'qr_code',
        'status',
    ];

    /**
     * Expose the public-disk URLs as virtual attributes.
     *
     * @var list<string>
     */
    protected $appends = ['image_url', 'qr_url'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'stock' => 'integer',
        ];
    }

    // ---------- Relationships ----------

    /**
     * @return BelongsTo<Category, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * @return HasMany<Loan>
     */
    public function loans(): HasMany
    {
        return $this->hasMany(Loan::class);
    }

    /**
     * Active loans (pending, approved, or currently borrowed).
     *
     * Used by:
     *  - inventory delete guard (Requirements 6.7, 6.8)
     *  - dashboard "borrowed" counter
     *
     * @return HasMany<Loan>
     */
    public function activeLoans(): HasMany
    {
        return $this->loans()->whereIn('status', self::ACTIVE_LOAN_STATUSES);
    }

    // ---------- Accessors ----------

    /**
     * Absolute URL for the inventory image, or null when no image is set.
     */
    protected function imageUrl(): Attribute
    {
        return Attribute::get(
            fn (): ?string => $this->image
                ? Storage::disk('public')->url($this->image)
                : null,
        );
    }

    /**
     * Absolute URL for the inventory QR image, or null when not generated yet.
     */
    protected function qrUrl(): Attribute
    {
        return Attribute::get(
            fn (): ?string => $this->qr_code
                ? Storage::disk('public')->url($this->qr_code)
                : null,
        );
    }
}
