<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown by LoanService when an action would borrow against zero stock
 * (Requirements 8.3, 10.2).
 */
class OutOfStockException extends RuntimeException
{
    public function __construct(string $message = 'Inventory is out of stock')
    {
        parent::__construct($message);
    }
}
