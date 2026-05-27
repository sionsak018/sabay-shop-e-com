<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\CategoryController;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Public product browsing
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class, 'show']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);

    // Create, update, delete require auth
    Route::post('/products', [ProductController::class, 'store']);
    Route::put('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

    Route::get('/orders', [OrderController::class, 'index']);      // Get user's orders
    Route::post('/checkout', [OrderController::class, 'store']);   // Create

    Route::get('/cart', [CartController::class, 'index']);               // Get user's cart
    Route::post('/cart/add', [CartController::class, 'addItem']);       // Add product
    Route::put('/cart/item/{id}', [CartController::class, 'updateItem']); // Update quantity
    Route::delete('/cart/item/{id}', [CartController::class, 'removeItem']); // Remove item
    Route::delete('/cart', [CartController::class, 'clear']);

    Route::apiResource('messages', MessageController::class)->only(['index', 'store']);
    Route::put('/messages/{id}/read', [MessageController::class, 'markAsRead']);

    Route::get('/categories', [CategoryController::class, 'index']);
});
