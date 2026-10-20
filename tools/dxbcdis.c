/* dxbcdis: disassemble DXBC shader blobs with vkd3d-shader (debugging aid)
 *   wine dxbcdis.exe file.dxbc [...] */
#include <stdio.h>
#include <stdlib.h>
#include <vkd3d_shader.h>

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++)
    {
        struct vkd3d_shader_compile_info info = {VKD3D_SHADER_STRUCTURE_TYPE_COMPILE_INFO};
        struct vkd3d_shader_code out = {0};
        char *messages = NULL;
        FILE *f = fopen(argv[i], "rb");
        long size;
        void *data;
        int ret;

        if (!f) { fprintf(stderr, "can't open %s\n", argv[i]); continue; }
        fseek(f, 0, SEEK_END); size = ftell(f); fseek(f, 0, SEEK_SET);
        data = malloc(size);
        fread(data, 1, size, f);
        fclose(f);

        info.source.code = data;
        info.source.size = size;
        info.source_type = VKD3D_SHADER_SOURCE_DXBC_TPF;
        info.target_type = VKD3D_SHADER_TARGET_D3D_ASM;
        info.log_level = VKD3D_SHADER_LOG_WARNING;
        ret = vkd3d_shader_compile(&info, &out, &messages);
        printf("// %s (%d)\n", argv[i], ret);
        if (out.code) fwrite(out.code, 1, out.size, stdout);
        if (messages) fprintf(stderr, "%s", messages);
        vkd3d_shader_free_shader_code(&out);
        vkd3d_shader_free_messages(messages);
        free(data);
    }
    return 0;
}
