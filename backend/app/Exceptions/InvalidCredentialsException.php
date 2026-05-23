<?php

namespace App\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Thrown by AuthService::login when the supplied NIM is unknown or
 * the password does not match. Mapped to HTTP 401 by the global
 * exception handler with a generic "Invalid credentials" message
 * (Requirements 2.2, 2.3) so attackers can't enumerate NIMs.
 */
class InvalidCredentialsException extends HttpException
{
    public function __construct(string $message = 'Invalid credentials')
    {
        parent::__construct(401, $message);
    }
}
