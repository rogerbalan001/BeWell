/**
 * Puerto de cifrado a nivel de campo para información clínica (decisión D9).
 * La implementación por defecto usa AES-256-GCM explícito (equivale a usar
 * cifrado explícito del driver en MongoDB Community). En producción se puede
 * sustituir por Queryable Encryption / CSFLE sin tocar los servicios.
 */
export abstract class CifradorCampos {
  abstract cifrar(texto: string): string;
  abstract descifrar(cifrado: string): string;
  /** HMAC determinista para buscar por igualdad sin guardar el valor en claro. */
  abstract huella(texto: string): string;

  cifrarOpcional(texto?: string | null): string | undefined {
    return texto ? this.cifrar(texto) : undefined;
  }
  descifrarOpcional(cifrado?: string | null): string | undefined {
    return cifrado ? this.descifrar(cifrado) : undefined;
  }
  cifrarLista(valores: string[] = []): string[] {
    return valores.map((v) => this.cifrar(v));
  }
  descifrarLista(valores: string[] = []): string[] {
    return valores.map((v) => this.descifrar(v));
  }
}
