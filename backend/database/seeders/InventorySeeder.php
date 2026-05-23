<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class InventorySeeder extends Seeder
{
    /**
     * Seed a few sample inventory items per category so the dashboard
     * and mobile inventory list are not empty out of the box.
     *
     * Inventory codes follow the INV-NNN convention referenced by the
     * QR design.
     */
    public function run(): void
    {
        $now = now();

        $categoryIds = DB::table('categories')
            ->pluck('id', 'name')
            ->all();

        $items = [
            ['Microcontroller', 'Arduino Uno R3', 'INV-001', 5, 'Standard ATmega328P development board.'],
            ['Microcontroller', 'ESP32 DevKit', 'INV-002', 4, 'Wi-Fi + Bluetooth microcontroller.'],
            ['Camera', 'Logitech C920 Webcam', 'INV-010', 2, 'Full-HD USB webcam.'],
            ['Networking', 'TP-Link Archer Router', 'INV-020', 3, 'Dual-band wireless router.'],
            ['Sensor', 'DHT22 Temperature Sensor', 'INV-030', 10, 'Digital temperature & humidity sensor.'],
            ['Toolkit', 'Soldering Toolkit', 'INV-040', 6, 'Solder iron, tin, multimeter, helping hands.'],
            ['Projector', 'Epson EB-X05', 'INV-050', 1, 'XGA classroom projector.'],
        ];

        $rows = [];
        foreach ($items as [$category, $name, $code, $stock, $description]) {
            $categoryId = $categoryIds[$category] ?? null;
            if ($categoryId === null) {
                continue;
            }

            $rows[] = [
                'category_id' => $categoryId,
                'name' => $name,
                'code' => $code,
                'stock' => $stock,
                'description' => $description,
                'image' => null,
                'qr_code' => null,
                'status' => $stock > 0 ? 'available' : 'out_of_stock',
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        if ($rows === []) {
            return;
        }

        DB::table('inventories')->upsert(
            $rows,
            uniqueBy: ['code'],
            update: ['name', 'category_id', 'stock', 'description', 'status', 'updated_at'],
        );
    }
}
