[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$contentPath = Join-Path $projectRoot 'content\productos.json'
$data = Get-Content -Raw -LiteralPath $contentPath -Encoding UTF8 | ConvertFrom-Json
$destinationRoot = Join-Path $projectRoot 'assets\productos'
$client = New-Object System.Net.WebClient
$client.Headers.Add('User-Agent', 'Mozilla/5.0')
$downloaded = 0
$reused = 0

try {
  foreach ($product in $data.products) {
    $productDirectory = Join-Path $destinationRoot $product.slug
    [System.IO.Directory]::CreateDirectory($productDirectory) | Out-Null
    foreach ($imageReference in $product.images) {
      $absoluteUri = $null
      $isRemote = [Uri]::TryCreate($imageReference, [UriKind]::Absolute, [ref]$absoluteUri) -and $absoluteUri.Scheme -in @('http','https')
      if (-not $isRemote) {
        $normalized = $imageReference.Replace('/',[System.IO.Path]::DirectorySeparatorChar)
        $localPath = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $normalized))
        if (-not $localPath.StartsWith($projectRoot + [System.IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
          throw "Local image is outside the project: $imageReference"
        }
        if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) { throw "Missing local image: $localPath" }
        $reused++
        continue
      }

      $fileName = [System.IO.Path]::GetFileName($absoluteUri.AbsolutePath)
      $destination = Join-Path $productDirectory $fileName
      if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        $reused++
        continue
      }
      $client.DownloadFile($absoluteUri, $destination)
      $downloaded++
    }
  }
}
finally {
  $client.Dispose()
}

Write-Output "PRODUCTS=$($data.products.Count) DOWNLOADED=$downloaded REUSED=$reused TOTAL=$($downloaded + $reused)"
