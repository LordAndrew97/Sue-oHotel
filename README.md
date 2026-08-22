# SuenoHotel

## Descripción

Este repositorio contiene la web corporativa de SuenoHotel, desarrollada como una landing page moderna y funcional para mostrar la propuesta de la marca, productos, contacto y experiencia comercial.

## Contenido del proyecto

- Página principal: [index.html](index.html)
- Catálogo de productos: [catalogo_suenohotel.html](catalogo_suenohotel.html)
- Páginas individuales: [productos](productos)
- Datos centralizados: [content/productos.json](content/productos.json)
- Recursos visuales: [assets](assets)
- Script de productos: [assets/productos-suenohotel.js](assets/productos-suenohotel.js)

## Actualizar las fichas de producto

1. Edita `content/productos.json`.
2. Si cambian las imágenes de la fuente, ejecuta `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-product-images.ps1 -Force`.
3. Regenera las páginas con `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-product-pages.ps1`.

El generador crea una página estática por producto en `productos/` y actualiza los enlaces centralizados del catálogo. Las URLs públicas se sirven sin extensión, por ejemplo `/productos/almohadas`.

## Objetivo

Presentar la marca de forma profesional, clara y atractiva, destacando:

- Productos y categorías.
- Información de contacto.
- Opciones de cotización.
- Experiencia y propuesta de valor.

## Vista previa local

Puedes abrir `index.html` directamente o utilizar la vista previa integrada de VS Code. Los enlaces internos apuntan a los archivos `.html` para ser compatibles con servidores locales simples; al publicar, Cloudflare los redirige a las URLs limpias sin extensión.

## Repositorio remoto

El proyecto está publicado en GitHub en:

https://github.com/LordAndrew97/Sue-oHotel

## Estado

Proyecto en desarrollo y mantenimiento con enfoque en presentación visual, usabilidad y experiencia del usuario.
