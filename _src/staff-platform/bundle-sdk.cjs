const path=require('path');
const esbuild=require('esbuild');
esbuild.buildSync({entryPoints:[path.join(__dirname,'sdk-entry.js')],bundle:true,minify:true,format:'iife',platform:'browser',target:'es2022',outfile:path.join(__dirname,'supabase-client.js'),legalComments:'eof'});
console.log('SDK bundled: Supabase 2.119.0');
