! Suma de vectores: W = U + V
suma_vect:
    ld [%i1], %l0     ! Cargar primer elemento de U en %l0
    ld [%i2], %l1     ! Cargar primer elemento de V en %l1
    add %l0, %l1, %l2 ! Sumar U + V y almacenar en %l2
    st %l2, [%i3]     ! Guardar el resultado en W
    retl
    nop

! Escalamiento de vector: W = K * U
escala_vect:
    ld [%i1], %l0     ! Cargar primer elemento de U en %l0
    mov %i2, %l1      ! Cargar escalar K en %l1
    mulx %l0, %l1, %l2 ! Multiplicar U * K
    st %l2, [%i3]     ! Guardar el resultado en W
    retl
    nop

! División escalar de vector: W = U / K
vector_sobre_esc:
    ld [%i1], %l0     ! Cargar primer elemento de U en %l0
    mov %i2, %l1      ! Cargar escalar K en %l1
    sdivx %l0, %l1, %l2 ! Dividir U / K
    st %l2, [%i3]     ! Guardar el resultado en W
    retl
    nop

! Un paso del cálculo: Actualización de posición
! %i0: número de elementos de los vectores
! %i1: dirección de memoria de Pos_i
! %i2: dirección de memoria de V_i
! %i3: escalar KV
! %i4: escalar Paso (Delta tiempo t)
un_paso:
    save %sp, -96, %sp  ! Crear un marco de pila

    mov %i0, %l7       ! Número de elementos del vector
    mov %i3, %l6       ! KV en %l6
    mov %i4, %l5       ! Paso (t) en %l5

    ! Inicializar punteros a las direcciones de memoria
    mov %i1, %l3       ! Dirección de Pos_i
    mov %i2, %l4       ! Dirección de V_i

ciclo_elementos:
    subcc %l7, 1, %l7  ! Decrementar número de elementos
    be fin_paso        ! Si todos los elementos están procesados, termina
    nop                ! Relleno de pipeline

    ld [%l4], %l0      ! Cargar elemento actual de V_i en %l0
    mulx %l0, %l6, %l1 ! Calcular KV * V (almacenar en %l1)
    mulx %l1, %l5, %l2 ! Calcular (KV * V * t), almacenar en %l2
    ld [%l3], %l1      ! Cargar elemento actual de Pos_i en %l1
    add %l1, %l2, %l1  ! Sumar Pos_i + DeltaPos
    st %l1, [%l3]      ! Guardar resultado actualizado en Pos_i

    add %l4, 4, %l4    ! Avanzar al siguiente elemento de V_i
    add %l3, 4, %l3    ! Avanzar al siguiente elemento de Pos_i

    ba ciclo_elementos ! Volver al inicio del ciclo
    nop                ! Relleno de pipeline

fin_paso:
    ret                 ! Retorna a la función principal
    restore             ! Restaurar marco de pila

! Acumula los pasos (ciclo completo para múltiples pasos)
! %i0: número de elementos de los vectores
! %i1: dirección de memoria de Pos_i
! %i2: dirección de memoria de V_i
! %i3: escalar KV
! %i4: escalar Paso (Delta tiempo t)
! %i5: número total de pasos
acumula_pasos:
    save %sp, -96, %sp  ! Crear un marco de pila

    mov %i5, %l7       ! Número total de pasos en %l7

ciclo_pasos:
    subcc %l7, 1, %l7  ! Decrementar el número de pasos
    be fin_acumula     ! Si llega a cero, termina
    nop                ! Relleno de pipeline

    call un_paso       ! Llama a la función un_paso
    nop                ! Relleno de pipeline

    ba ciclo_pasos     ! Volver al inicio del ciclo
    nop                ! Relleno de pipeline

fin_acumula:
    ret                 ! Retorna a la función principal
    restore             ! Restaurar marco de pila
