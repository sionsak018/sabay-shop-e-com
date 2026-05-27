<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Message;

class MessageController extends Controller
{
    public function index(Request $request)
{
    // Get all conversations for the logged-in user
    $messages = Message::where('from_user_id', $request->user()->id)
                ->orWhere('to_user_id', $request->user()->id)
                ->with(['fromUser', 'toUser', 'product'])
                ->orderBy('created_at', 'desc')
                ->get();
    return response()->json($messages);
}

public function store(Request $request)
{
    $request->validate([
        'to_user_id' => 'required|exists:users,id',
        'message' => 'required|string',
        'product_id' => 'nullable|exists:products,id',
    ]);

    $message = Message::create([
    'from_user_id' => $request->user()->id,
    'to_user_id' => $request->to_user_id,
    'product_id' => $request->product_id,
    'message' => $request->message,   // use 'message'
]);

    return response()->json($message, 201);
}

public function markAsRead(int $id, Request $request)
{
    $message = Message::where('to_user_id', $request->user()->id)->findOrFail($id);
    $message->update(['is_read' => true]);
    return response()->json(['message' => 'Marked as read']);
}
}
