! Sección de datos
.section ".bss"
  pasos:       .word   0         ! Total de iteraciones a ejecutar
  Kv:          .word   0         ! Coeficiente de resistencia viscosa
  m:           .word   0         ! Masa del objeto
  t:           .word   0         ! Incremento de tiempo por iteración
  Pos_i:       .word   0, 0      ! Coordenadas iniciales (x, y)
  V_i:         .word   0, 0      ! Velocidades iniciales (Vx, Vy)
  F:           .word   0, 0      ! Fuerza aplicada (Fx, Fy)
  V:           .word   0, 0      ! Velocidades actuales (Vx, Vy)
  delta_pos:   .word   0, 0      ! Incrementos de posición (dx, dy)
  pos_lista:   .skip   400       ! Memoria para registrar posiciones (200 pasos máx, 2 componentes por paso)

! Sección de código
.section ".text"
.global main

main:
    ! Configuración inicial
    LD   [%lo(V_i)], %o0       ! Cargar la velocidad inicial en x (Vx) a %o0
    ST   %o0, [%lo(V)]         ! Guardar Vx en el vector de velocidad actual
    LD   [%lo(V_i)+4], %o1     ! Cargar la velocidad inicial en y (Vy) a %o1
    ST   %o1, [%lo(V)+4]       ! Guardar Vy en el vector de velocidad actual
    LD   [%lo(Pos_i)], %o2     ! Cargar la posición inicial en x (Pos_x) a %o2
    ST   %o2, [%lo(pos_lista)] ! Guardar Pos_x en la lista de posiciones
    LD   [%lo(Pos_i)+4], %o3   ! Cargar la posición inicial en y (Pos_y) a %o3
    ST   %o3, [%lo(pos_lista)+4]! Guardar Pos_y en la lista de posiciones
    LD   [%lo(pasos)], %o4     ! Leer el número total de pasos a realizar
    LD   [%lo(t)], %o5         ! Leer el valor del delta de tiempo
    SETHI %hi(0), %l0          ! Inicializar el contador de iteraciones a 0
    SETHI %hi(pos_lista), %l1  ! Dirección inicial de la lista de posiciones

loop_pasos:
    CMP   %l0, %o4             ! Comparar el contador con el número total de pasos
    BGE   end                  ! Si se alcanzó el límite, salir del bucle
    NOP

    ! Calcular la fuerza de resistencia: F = -Kv * V
    LD    [%lo(Kv)], %o6       ! Leer el coeficiente de viscosidad (Kv)
    LD    [%lo(V)], %o7        ! Leer la velocidad actual en x (Vx)
    SMUL  %o6, %o7, %o8        ! Calcular Fx = Kv * Vx
    NEG   %o8                  ! Fx = -Fx
    ST    %o8, [%lo(F)]        ! Almacenar el resultado en F[0]
    LD    [%lo(V)+4], %o7      ! Leer la velocidad actual en y (Vy)
    SMUL  %o6, %o7, %o8        ! Calcular Fy = Kv * Vy
    NEG   %o8                  ! Fy = -Fy
    ST    %o8, [%lo(F)+4]      ! Almacenar el resultado en F[1]

    ! Determinar la aceleración: a = F / m
    LD    [%lo(m)], %o9        ! Cargar la masa (m)
    LD    [%lo(F)], %o10       ! Cargar Fx
    SDIV  %o10, %o9, %o11      ! Calcular ax = Fx / m
    ST    %o11, [%lo(delta_pos)] ! Guardar ax en delta_pos[0]
    LD    [%lo(F)+4], %o10     ! Cargar Fy
    SDIV  %o10, %o9, %o11      ! Calcular ay = Fy / m
    ST    %o11, [%lo(delta_pos)+4] ! Guardar ay en delta_pos[1]

    ! Actualizar velocidad: V = V + a * t
    LD    [%lo(delta_pos)], %o12 ! Leer ax
    SMUL  %o12, %o5, %o12      ! Multiplicar ax por delta t
    LD    [%lo(V)], %o13       ! Leer Vx actual
    ADD   %o13, %o12, %o13     ! Vx nuevo = Vx + (ax * t)
    ST    %o13, [%lo(V)]       ! Guardar Vx actualizado
    LD    [%lo(delta_pos)+4], %o12 ! Leer ay
    SMUL  %o12, %o5, %o12      ! Multiplicar ay por delta t
    LD    [%lo(V)+4], %o13     ! Leer Vy actual
    ADD   %o13, %o12, %o13     ! Vy nuevo = Vy + (ay * t)
    ST    %o13, [%lo(V)+4]     ! Guardar Vy actualizado

    ! Calcular posición actual: delta_pos = V * t + (a * t^2) / 2
    SMUL  %o5, %o5, %o14       ! Calcular t^2
    LD    [%lo(delta_pos)], %o12 ! Leer ax
    SMUL  %o12, %o14, %o14     ! Calcular ax * t^2
    LD    [%lo(V)], %o15       ! Leer Vx
    SMUL  %o15, %o5, %o18      ! Calcular Vx * t
    ADD   %o18, %o14, %o14     ! Sumar ambos términos: dx = Vx * t + (ax * t^2)
    SRL   %o14, %o14, 1        ! Dividir por 2
    ST    %o14, [%lo(delta_pos)] ! Guardar dx en delta_pos[0]

    SMUL  %o5, %o5, %o14       ! Calcular t^2
    LD    [%lo(delta_pos)+4], %o12 ! Leer ay
    SMUL  %o12, %o14, %o14     ! Calcular ay * t^2
    LD    [%lo(V)+4], %o15       ! Leer Vy
    SMUL  %o15, %o5, %o18      ! Calcular Vy * t
    ADD   %o18, %o14, %o14     ! Sumar ambos términos: dy = Vy * t + (ay * t^2)
    SRL   %o14, %o14, 1        ! Dividir por 2
    ST    %o14, [%lo(delta_pos)+4] ! Guardar dy en delta_pos[1]

    ! Actualizar posición y registrar en la lista
    LD    [%l1], %o16          ! Leer Pos_x actual
    ADD   %o16, %o14, %o16     ! Actualizar Pos_x
    ST    %o16, [%l1+8]        ! Guardar nueva Pos_x en la lista
    LD    [%l1+4], %o17        ! Leer Pos_y actual
    ADD   %o17, %o15, %o17     ! Actualizar Pos_y
    ST    %o17, [%l1+12]       ! Guardar nueva Pos_y en la lista

    ADD   %l1, 8, %l1          ! Mover el puntero a la siguiente entrada de la lista
    INC   %l0                  ! Incrementar el contador
    BA    loop_pasos           ! Repetir el bucle
    NOP

end:
    RETL                       ! Terminar el programa
    NOP
