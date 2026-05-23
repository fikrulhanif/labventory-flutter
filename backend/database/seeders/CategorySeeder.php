<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CategorySeeder extends Seeder
{
    /**
     * Seed a small but representative set of inventory categories.
     */
    public function run(): void
    {
        $now = now();

        $names = [
            'Microcontroller',
            'Camera',
            'Networking',
            'Sensor',
            'Toolkit',
            'Projector',
        ];

        $rows = array_map(
            fn (string $name) => [
                'name' => $name,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            $names,
        );

        DB::table('categories')->upsert(
            $rows,
            uniqueBy: ['name'],
            update: ['updated_at'],
        );
    }
}
