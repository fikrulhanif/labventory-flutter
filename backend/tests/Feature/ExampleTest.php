<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * The site root redirects unauthenticated browsers to /login,
     * which is the canonical landing page for the admin dashboard.
     */
    public function test_root_redirects_guests_to_login(): void
    {
        $this->get('/')->assertRedirect('/login');
    }
}
