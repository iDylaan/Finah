import json

# Cargar el archivo fuente
with open('C:\\Users\\Sun\\Downloads\\json.txt', 'r', encoding='utf-8') as file:
    # Saltar la línea inicial no válida si existe
    content = file.read()
    if content.startswith(")]}'"):
        content = content.split('\n', 1)[1]

    data = json.loads(content)

# Extraer los nombres de los íconos
icon_names = [icon["name"] for icon in data.get("icons", [])]

# Guardar en un archivo JSON
with open('C:\\Users\\Sun\\Documents\\GitHub\\Finheal\\src\\assets\\demo\\constants\\material-symbols.json', 'w', encoding='utf-8') as out_file:
    json.dump(icon_names, out_file, indent=4, ensure_ascii=False)

print(f"✅ Se exportaron {len(icon_names)} íconos a material-symbols.json")
