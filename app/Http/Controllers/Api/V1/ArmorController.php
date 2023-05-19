<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\V1\ArmorResource;
use App\Models\Armor;
use Illuminate\Http\Request;

class ArmorController extends Controller
{
    public function __construct(
        private Armor $model
    ) {
    }

    public function index(Request $request)
    {
        $data = cache()->remember($request->generateCacheKey(), config('settings.cache_seconds'), function () use ($request) {
            return $this->model
                ->query()
                ->when($request->input('category_id'), function ($query, $category) {
                    $query->where('category_id', $category);
                })
                ->when($request->input('subcategory_id'), function ($query, $category) {
                    $query->where('subcategory_id', $category);
                })
                ->when($request->input('tier'), function ($query, $tier) {
                    $query->where('tier', $tier);
                })
                ->get();
        });

        return ArmorResource::collection($data);
    }
}
