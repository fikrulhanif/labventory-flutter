<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class RoleUserSeeder extends Seeder
{
    /**
     * Seed default admin and laboran accounts for the admin dashboard.
     *
     * Both records have nim = NULL because admin and laboran do not
     * borrow inventory and use email + password to log into the web
     * dashboard.
     */
    public function run(): void
    {
        $now = now();

        DB::table('users')->upsert(
            [
                [
                    'name' => 'Administrator',
                    'nim' => null,
                    'email' => 'admin@labventory.test',
                    'password' => Hash::make('password'),
                    'role' => 'admin',
                    'status' => 'active',
                    'created_at' => $now,
                    'updated_at' => $now,
                ],
                [
                    'name' => 'Laboran',
                    'nim' => null,
                    'email' => 'laboran@labventory.test',
                    'password' => Hash::make('password'),
                    'role' => 'laboran',
                    'status' => 'active',
                    'created_at' => $now,
                    'updated_at' => $now,
                ],
            ],
            uniqueBy: ['email'],
            update: ['name', 'role', 'status', 'updated_at'],
        );
    }
}
