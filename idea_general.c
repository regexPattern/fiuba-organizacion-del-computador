#include <stdio.h>
#include <stdbool.h>

#define FILAS 7
#define COLUMNAS 7

// Estado de cada posición en el tablero
typedef enum { VACIO, SOLDADO, OFICIAL } Estado;

// Tablero de juego
Estado tablero[FILAS][COLUMNAS];

// Inicializa el tablero con la disposición inicial de soldados y oficiales
void inicializar_tablero() {
    // Aca tendriamos que completar segun corresponda
    for (int i = 0; i < FILAS; i++) {
        for (int j = 0; j < COLUMNAS; j++) {
            tablero[i][j] = VACIO;
        }
    }
    
    //ej
    tablero[5][3] = OFICIAL;
    tablero[6][3] = OFICIAL;
}


void mostrar_tablero()


// Mueve una pieza (soldado u oficial) en el tablero
bool mover_pieza(int x_origen, int y_origen, int x_destino, int y_destino) {
    // Verifica si el movimiento es válido según las reglas del juego
    if (/* condiciones de movimiento válido */) {
        tablero[x_destino][y_destino] = tablero[x_origen][y_origen];
        tablero[x_origen][y_origen] = VACIO;
        return true;
    }
    return false;
}

// Verifica si el juego ha terminado
bool verificar_si_termino_juego() {
    // Condiciones de finalización: soldados ocupan fortaleza, oficiales rodeados, etc.
    return false;
}

// Ejecuta el turno de un jugador
void jugar_turno(bool esTurnoSoldado) {
    int x_origen, y_origen, x_destino, y_destino;
    printf("Ingrese las coordenadas de la pieza a mover (x y) y las coordenadas de destino (x y): ");
    scanf("%d %d %d %d", &x_origen, &y_origen, &x_destino, &y_destino);

    if (mover_pieza(x_origen, y_origen, x_destino, y_destino)) {
        printf("Movimiento realizado.\n");
    } else {
        printf("Movimiento inválido.\n");
    }
}

int main() {
    bool juegoActivo = true;
    bool esTurnoSoldado = true;

    inicializar_tablero();
    mostrar_tablero();

    while (juegoActivo) {
        jugar_turno(esTurnoSoldado);
        mostrar_tablero();

        if (verificar_si_termino_juego()) {
            printf("El juego ha terminado.\n");
            juegoActivo = false;
        }

        // Cambia de turno
        esTurnoSoldado = !esTurnoSoldado;
    }

    return 0;
}
