[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$contentPath = Join-Path $projectRoot 'content\productos.json'
$templatePath = Join-Path $projectRoot 'templates\producto.html'
$outputDirectory = Join-Path $projectRoot 'productos'
$catalogDataPath = Join-Path $projectRoot 'assets\productos-suenohotel.js'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$data = Get-Content -Raw -LiteralPath $contentPath -Encoding UTF8 | ConvertFrom-Json
$template = Get-Content -Raw -LiteralPath $templatePath -Encoding UTF8
$brandName = 'Sue' + [char]0x00F1 + 'oHotel'
$galleryLabel = 'Galer' + [char]0x00ED + 'a'
$imagesLabel = 'im' + [char]0x00E1 + 'genes'
Add-Type -AssemblyName System.Drawing

function Encode-Html([AllowNull()][string]$value) {
  if ($null -eq $value) { return '' }
  return [System.Net.WebUtility]::HtmlEncode($value)
}

function Get-LocalImagePath($product, [string]$imageReference) {
  $absoluteUri = $null
  if ([Uri]::TryCreate($imageReference, [UriKind]::Absolute, [ref]$absoluteUri) -and $absoluteUri.Scheme -in @('http','https')) {
    $fileName = [System.IO.Path]::GetFileName($absoluteUri.AbsolutePath)
    return "../assets/productos/$($product.slug)/$fileName"
  }

  $normalized = $imageReference.Replace('\','/')
  if ($normalized.StartsWith('../')) { return $normalized }
  if ($normalized.StartsWith('/')) { return '..' + $normalized }
  $normalized = $normalized -replace '^\./',''
  return '../' + $normalized
}

function Get-ImageSize([string]$relativePath) {
  $absolutePath = Join-Path $projectRoot ($relativePath -replace '^\.\./','')
  $image = [System.Drawing.Image]::FromFile($absolutePath)
  try { return @{ Width=$image.Width; Height=$image.Height } }
  finally { $image.Dispose() }
}

function Render-List($items) {
  $listItems = @($items | ForEach-Object { '<li>' + (Encode-Html $_) + '</li>' }) -join ''
  return '<ul class="spec-list">' + $listItems + '</ul>'
}

function Render-Block($block) {
  $heading = if ($block.heading) { '<h2>' + (Encode-Html $block.heading) + '</h2>' } else { '' }
  switch ($block.type) {
    'paragraph' { return '<section class="spec-block"><p>' + (Encode-Html $block.text) + '</p></section>' }
    'list' { return '<section class="spec-block">' + $heading + (Render-List $block.items) + '</section>' }
    'section' {
      $paragraphs = @($block.paragraphs | ForEach-Object { '<p>' + (Encode-Html $_) + '</p>' }) -join ''
      $items = if ($block.items) { Render-List $block.items } else { '' }
      return '<section class="spec-block">' + $heading + $paragraphs + $items + '</section>'
    }
    'table' {
      $headers = @($block.headers | ForEach-Object { '<th scope="col">' + (Encode-Html $_) + '</th>' }) -join ''
      $rows = @($block.rows | ForEach-Object {
        $cells = @($_ | ForEach-Object { '<td>' + (Encode-Html $_) + '</td>' }) -join ''
        '<tr>' + $cells + '</tr>'
      }) -join ''
      return '<section class="spec-block">' + $heading + '<div class="table-scroll"><table class="spec-table"><thead><tr>' + $headers + '</tr></thead><tbody>' + $rows + '</tbody></table></div></section>'
    }
    'note' { return '<aside class="spec-block spec-note">' + (Encode-Html $block.text) + '</aside>' }
    default { throw "Unknown block type '$($block.type)'" }
  }
}

$slugs = @($data.products | ForEach-Object { $_.slug })
if (($slugs | Select-Object -Unique).Count -ne $slugs.Count) { throw 'Duplicate product slugs found.' }
if ($data.products.Count -ne 14) { throw "Expected 14 products, found $($data.products.Count)." }
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$generatedFiles = New-Object System.Collections.Generic.List[string]

foreach ($product in $data.products) {
  if (-not $product.slug -or -not $product.name -or -not $product.blocks -or -not $product.images) { throw "Incomplete product data for '$($product.slug)'." }
  foreach ($imageUrl in $product.images) {
    $localRelative = Get-LocalImagePath $product $imageUrl
    $localAbsolute = Join-Path $projectRoot ($localRelative -replace '^\.\./','')
    if (-not (Test-Path -LiteralPath $localAbsolute)) { throw "Missing local image: $localAbsolute" }
  }

  $productContent = @($product.blocks | ForEach-Object { Render-Block $_ }) -join "`n          "
  $heroImage = Get-LocalImagePath $product $product.images[0]
  $heroSize = Get-ImageSize $heroImage
  $galleryImages = @($product.images | Select-Object -Skip 1)
  if ($galleryImages.Count -gt 0) {
    $galleryCards = for ($index = 0; $index -lt $galleryImages.Count; $index++) {
      $localImage = Get-LocalImagePath $product $galleryImages[$index]
      $imageSize = Get-ImageSize $localImage
      $localFileName = [System.IO.Path]::GetFileName($localImage)
      $altProperty = if ($product.imageAlts) { $product.imageAlts.PSObject.Properties[$localFileName] } else { $null }
      $imageAltText = if ($altProperty) { [string]$altProperty.Value } else { "{0} - imagen {1}" -f $product.name,($index + 2) }
      $imageAlt = Encode-Html $imageAltText
      '<a class="gallery-card" href="' + $localImage + '" target="_blank" rel="noopener"><img loading="lazy" src="' + $localImage + '" alt="' + $imageAlt + '" width="' + $imageSize.Width + '" height="' + $imageSize.Height + '"></a>'
    }
    $gallerySection = '<section class="gallery sec" aria-labelledby="gallery-title"><div class="wrap"><div class="section-head"><div><span class="eyebrow">' + $galleryLabel + '</span><h2 id="gallery-title">' + (Encode-Html $product.name) + '</h2></div><span class="image-count">' + ([string]$product.images.Count) + ' ' + $imagesLabel + '</span></div><div class="gallery-grid">' + ($galleryCards -join '') + '</div></div></section>'
  }
  else { $gallerySection = '' }

  $headerProducts = @($data.products | ForEach-Object {
    $current = if ($_.slug -eq $product.slug) { ' aria-current="page"' } else { '' }
    '<li><a href="' + $_.slug + '.html"' + $current + '>' + (Encode-Html $_.name) + '</a></li>'
  }) -join ''
  $footerProducts = @($data.products | ForEach-Object { '<li><a href="' + $_.slug + '.html">' + (Encode-Html $_.name) + '</a></li>' }) -join ''
  $productIndex = [Array]::IndexOf($slugs, $product.slug)
  $relatedIndexes = @(1,2,3 | ForEach-Object { ($productIndex + $_) % $data.products.Count })
  $relatedProducts = @($relatedIndexes | ForEach-Object {
    $related = $data.products[$_]
    $relatedSize = Get-ImageSize ('../' + $related.cardImage)
    '<a class="related-card" href="' + $related.slug + '.html"><img loading="lazy" src="../' + $related.cardImage + '" alt="" width="' + $relatedSize.Width + '" height="' + $relatedSize.Height + '"><span>' + (Encode-Html $related.name) + '</span></a>'
  }) -join ''

  $firstText = $null
  foreach ($block in $product.blocks) {
    if ($block.text) { $firstText = $block.text; break }
    if ($block.paragraphs) { $firstText = $block.paragraphs[0]; break }
    if ($block.items) { $firstText = $block.items[0]; break }
  }
  if (-not $firstText) { $firstText = $product.name }
  $description = $firstText
  if ($description.Length -gt 155) { $description = $description.Substring(0,152).TrimEnd() + '...' }
  $canonical = "https://magnotex.humads.workers.dev/productos/$($product.slug)"
  $ogFile = [System.IO.Path]::GetFileName((Get-LocalImagePath $product $product.images[0]))
  $ogImage = "https://magnotex.humads.workers.dev/assets/productos/$($product.slug)/$ogFile"

  $html = $template
  $replacements = [ordered]@{
    '{{TITLE}}' = (Encode-Html ("{0} | {1}" -f $product.name,$brandName))
    '{{DESCRIPTION}}' = (Encode-Html $description)
    '{{CANONICAL}}' = (Encode-Html $canonical)
    '{{OG_IMAGE}}' = (Encode-Html $ogImage)
    '{{PRODUCT_NAME}}' = (Encode-Html $product.name)
    '{{HEADER_PRODUCTS}}' = $headerProducts
    '{{FOOTER_PRODUCTS}}' = $footerProducts
    '{{HERO_IMAGE}}' = $heroImage
    '{{HERO_WIDTH}}' = ([string]$heroSize.Width)
    '{{HERO_HEIGHT}}' = ([string]$heroSize.Height)
    '{{PRODUCT_CONTENT}}' = $productContent
    '{{GALLERY_SECTION}}' = $gallerySection
    '{{RELATED_PRODUCTS}}' = $relatedProducts
  }
  foreach ($entry in $replacements.GetEnumerator()) { $html = $html.Replace($entry.Key,[string]$entry.Value) }
  if ($html -match '\{\{[A-Z_]+\}\}') { throw "Unresolved template token for '$($product.slug)'." }
  $outputPath = Join-Path $outputDirectory ($product.slug + '.html')
  [System.IO.File]::WriteAllText($outputPath,$html,$utf8NoBom)
  $generatedFiles.Add($outputPath)
}

$catalogProducts = @($data.products | ForEach-Object {
  $cardSize = Get-ImageSize $_.cardImage
  [ordered]@{ n=$_.name; slug=$_.slug; img=$_.cardImage; href=("productos/" + $_.slug + ".html"); w=$cardSize.Width; h=$cardSize.Height }
})
$catalogObject = [ordered]@{ allProducts=$catalogProducts; featuredSlugs=@($data.featuredSlugs) }
$catalogJson = $catalogObject | ConvertTo-Json -Depth 8 -Compress
[System.IO.File]::WriteAllText($catalogDataPath,"window.SUENOHOTEL_PRODUCTS=$catalogJson;`n",$utf8NoBom)
$actualOutputs = @(Get-ChildItem -LiteralPath $outputDirectory -Filter '*.html' -File)
if ($actualOutputs.Count -ne $data.products.Count) { throw "Output count mismatch: $($actualOutputs.Count) files for $($data.products.Count) products." }
Write-Output "PRODUCTS=$($data.products.Count) PAGES=$($generatedFiles.Count) CATALOG_DATA=$catalogDataPath"
