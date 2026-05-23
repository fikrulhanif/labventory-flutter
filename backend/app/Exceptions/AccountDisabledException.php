<?php

namespace App\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Thrown by AuthService::login when the supplied credentials match a
 * user record whose status is "inactive". Mapped to HTTP 403 with
 * "Account is disabled" by the global exception handler (Requirement
 * 2.4).
 */
class AccountDisabledException extends HttpException
{
    public function __construct(string $message = 'Account is disabled')
    {
        parent::__construct(403, $message);
    }
}
