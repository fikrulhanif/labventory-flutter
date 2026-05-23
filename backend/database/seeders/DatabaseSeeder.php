<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database with the default admin/laboran
     * accounts plus a representative inventory catalog.
     */
    public function run(): void
    {
        $this->call([
            RoleUserSeeder::class,
            CategorySeeder::class,
            InventorySeeder::class,
        ]);
    }
}
