<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\URL;

/**
 * @mixin \App\Models\Loan
 *
 * Serializes a loan record for the mobile API. The KTM document is
 * exposed only via the gated streaming endpoint, never as a raw
 * /storage/ktm/... URL (Requirement 18.6).
 */
class LoanResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'borrow_date' => $this->borrow_date?->format('Y-m-d'),
            'return_date' => $this->return_date?->format('Y-m-d'),
            'notes' => $this->notes,
            'reject_reason' => $this->reject_reason,
            'document_url' => URL::route('api.loans.document', ['id' => $this->id]),
            'picked_up_at' => $this->picked_up_at?->utc()->format('Y-m-d\TH:i:s\Z'),
            'returned_at' => $this->returned_at?->utc()->format('Y-m-d\TH:i:s\Z'),
            'user' => $this->whenLoaded(
                'user',
                fn () => new UserResource($this->user),
            ),
            'inventory' => $this->whenLoaded(
                'inventory',
                fn () => new InventoryResource($this->inventory),
            ),
            'created_at' => $this->created_at?->utc()->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $this->updated_at?->utc()->format('Y-m-d\TH:i:s\Z'),
        ];
    }
}
