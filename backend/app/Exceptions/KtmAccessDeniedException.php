<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown by the KTM streaming controller when the requester is neither the
 * loan owner nor a staff user (Requirement 18.6). Translated to HTTP 403
 * by the global exception handler.
 */
class KtmAccessDeniedException extends RuntimeException
{
    public function __construct(string $message = 'Forbidden')
    {
        parent::__construct($message);
    }
}
