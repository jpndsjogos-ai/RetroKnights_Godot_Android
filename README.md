# Retro Knights: Rise of Steel

Base de um Beat 'em Up 2D/2.5D para Android usando Godot 4.7.2 + GDScript.

## Mecânicas
- Movimento em quatro direções no plano da rua.
- Ataque, pulo, parry e especial.
- Especial consome HP.
- Inimigos com hitboxes/hurtboxes.
- XP e progressão contínua.
- Níveis 1–3: ferro.
- Níveis 4–7: aço.
- Nível 8+: ouro/runas.
- HUD e controles touch criados por código.

## Build local
1. Instale Godot 4.7.2 Standard.
2. Abra o projeto.
3. Projeto > Exportar > Android.
4. Selecione o preset Android e exporte.

## Build no GitHub
O workflow `.github/workflows/build-android.yml` instala Java 17, Android SDK/NDK, baixa o Godot e os templates correspondentes e executa:

`godot --headless --path . --export-debug "Android" build/RetroKnights-debug.apk`

O APK fica em **Actions > workflow > execução > Artifacts**.

## Próxima evolução
Substituir os SVGs de placeholder por spritesheets reais, adicionar animações, chefes, fases, câmera lateral, combos e persistência de save.
