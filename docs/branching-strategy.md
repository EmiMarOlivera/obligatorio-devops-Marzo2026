# Estrategia de Branhing

## Estrategia elegida: GitHub Flow

## ¿Por qué se eligio GitHub Flow?
GitHub Flow es simple, directo y se adapta bien a un equipo chico. No requiere gestionar múltiples ramas de larga duración como Git Flow, lo que reduce la complejidad operativa y el riesgo de conflictos. Y trunk-based es demasiado riesgoso.

## ¿Cómo trabajamos?

- **main** es la rama principal y está protegida. Ningún integrante puede pushear directo a ella. Ncesita PR previo
- Cada tarea se desarrolla en una rama propia con el formato `feature/nombre-de-la-tarea`.
- Cuando la tarea está lista se abre un Pull Request hacia main.
- El PR debe ser aprobado por al menos un integrante antes de mergearse.
- Una vez mergeado, la rama feature se elimina.

## Ramas del proyecto

| Rama | Propósito |
|---|---|
| `main` | Código estable y aprobado |
| `feature/*` | Desarrollo de tareas individuales |

## Justificación en el contexto del proyecto
El proyecto tiene un equipo chico, un plazo de un mes y múltiples áreas de trabajo en paralelo. GitHub Flow permite que se trabaje de forma independiente en la tarea, con revisión obligatoria antes de integrar como pide la letra, sin la sobrecarga de gestionar ramas de release o hotfix que no son necesarias en esta etapa, y son mas avanzadas
