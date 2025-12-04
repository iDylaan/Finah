import sharp from 'sharp';
import { readFileSync } from 'fs';

const svg = readFileSync('public/imgs/FinahIsotipo.svg');

// Generar icono de 192x192
await sharp(svg)
  .resize(192, 192)
  .png()
  .toFile('public/pwa-192x192.png');

console.log('✅ Creado: pwa-192x192.png');

// Generar icono de 512x512
await sharp(svg)
  .resize(512, 512)
  .png()
  .toFile('public/pwa-512x512.png');

console.log('✅ Creado: pwa-512x512.png');

// Generar favicon
await sharp(svg)
  .resize(32, 32)
  .png()
  .toFile('public/favicon.png');

console.log('✅ Creado: favicon.png');

// Generar apple-touch-icon
await sharp(svg)
  .resize(180, 180)
  .png()
  .toFile('public/apple-touch-icon.png');

console.log('✅ Creado: apple-touch-icon.png');

console.log('\n🎉 Todos los iconos PWA generados exitosamente!');
