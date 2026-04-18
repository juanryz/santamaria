<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Support\Facades\Crypt;

class CctvCamera extends Model
{
    use HasUuids;

    protected $table = 'cctv_cameras';

    protected $fillable = [
        'camera_label', 'location_type', 'ip_address',
        'stream_url', 'username', 'password_encrypted',
        'stream_type', 'area_detail', 'is_active', 'added_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected $hidden = ['password_encrypted'];

    public function addedByUser() { return $this->belongsTo(User::class, 'added_by'); }

    /** Enkripsi password saat set, dekripsi saat ambil. */
    public function setPasswordAttribute(?string $value): void
    {
        $this->attributes['password_encrypted'] =
            $value === null || $value === '' ? null : Crypt::encryptString($value);
    }

    public function getPasswordAttribute(): ?string
    {
        if (empty($this->password_encrypted)) return null;
        try {
            return Crypt::decryptString($this->password_encrypted);
        } catch (\Exception $e) {
            return null;
        }
    }

    /** Build authenticated stream URL untuk internal use (Owner view). */
    public function buildAuthenticatedStreamUrl(): string
    {
        $username = $this->username;
        $password = $this->password;
        if (!$username || !$password) return $this->stream_url;

        // Insert credentials into URL: rtsp://user:pass@host/path
        $url = $this->stream_url;
        $parsed = parse_url($url);
        if (!$parsed || empty($parsed['scheme']) || empty($parsed['host'])) return $url;

        $auth = urlencode($username) . ':' . urlencode($password) . '@';
        $path = $parsed['path'] ?? '';
        $query = isset($parsed['query']) ? '?' . $parsed['query'] : '';
        $port = isset($parsed['port']) ? ':' . $parsed['port'] : '';

        return "{$parsed['scheme']}://{$auth}{$parsed['host']}{$port}{$path}{$query}";
    }
}
