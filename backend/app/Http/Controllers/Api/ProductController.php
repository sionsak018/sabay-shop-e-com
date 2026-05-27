<?php

namespace App\Http\Controllers\Api;

use App\Models\Product;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
{
    $query = Product::with(['seller', 'category', 'images'])->where('status', 'active');

    if ($request->filled('keyword')) {
        $query->where('title', 'like', '%'.$request->keyword.'%')
              ->orWhere('description', 'like', '%'.$request->keyword.'%');
    }
    if ($request->filled('category_id')) {
        $query->where('category_id', $request->category_id);
    }
    if ($request->filled('min_price')) {
        $query->where('price', '>=', $request->min_price);
    }
    if ($request->filled('max_price')) {
        $query->where('price', '<=', $request->max_price);
    }
    if ($request->filled('location')) {
        $query->where('location', 'like', '%'.$request->location.'%');
    }

    return response()->json($query->latest()->paginate(20));
}

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'description' => 'required',
            'price' => 'required|numeric|min:0',
            'category_id' => 'required|exists:categories,id',
            'condition' => 'required|in:new,used',
            'location' => 'required|string',
            'images' => 'array|max:5',
            'images.*' => 'image|mimes:jpg,png|max:2048'
        ]);

        $product = $request->user()->products()->create($request->except('images'));

        // Handle image uploads (store in storage/app/public/products)
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $index => $image) {
                $path = $image->store('products', 'public');
                $product->images()->create([
                    'image_url' => $path,
                    'sort_order' => $index
                ]);
            }
        }

        return response()->json($product->load('images'), 201);
    }
    public function show($id)
{
    $product = Product::with(['seller', 'category', 'images'])
                ->where('id', $id)
                ->where('status', 'active')
                ->firstOrFail();
    return response()->json($product);
}
}
