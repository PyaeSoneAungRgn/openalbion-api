<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Scout\Searchable;
use Illuminate\Database\Eloquent\Casts\Attribute;

class Consumable extends Model
{
    use HasFactory;
    use Searchable;

    protected $fillable = [
        'category_id',
        'subcategory_id',
        'name',
        'identifier',
        'tier',
        'item_power',
        'path',
        'info',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function subcategory(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'subcategory_id');
    }

    public function consumbleStats(): HasMany
    {
        return $this->hasMany(ConsumableStat::class);
    }

    protected function tier(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => $value ? number_format($value, 1) : null,
        );
    }
}
