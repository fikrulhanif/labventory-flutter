<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Inventory
 *
 * Serializes an inventory record for the mobile API.
 *
 * - image_url and qr_url are absolute URLs resolvable by the Flutter
 *   client (Requirement 18.5, Property 44).
 * - timestamps are ISO 8601 UTC (Requirement 17.7).
 */
class InventoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'code' => $this->code,
            'stock' => (int) $this->stock,
            'status' => $this->status,
            'description' => $this->description,
            'image_url' => $this->image_url,
            'qr_url' => $this->qr_url,
            'category' => $this->whenLoaded(
                'category',
                fn () => new CategoryResource($this->category),
            ),
            'created_at' => $this->created_at?->utc()->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $this->updated_at?->utc()->format('Y-m-d\TH:i:s\Z'),
        ];
    }
}
