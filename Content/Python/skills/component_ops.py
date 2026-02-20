"""
컴포넌트 작업
===============
Actor의 컴포넌트에 접근하고, 컴포넌트의 변수/프로퍼티를 읽고 쓴다.
"""

import unreal


def get_component_variable(actor_name, component_class_name, variable_name):
    """Actor의 특정 컴포넌트의 변수를 읽는다.

    Args:
        actor_name (str): 액터의 내부 이름.
        component_class_name (str): 컴포넌트 클래스 이름 (예: "SceneCaptureComponent2D").
        variable_name (str): 읽을 변수/프로퍼티 이름.

    Returns:
        dict: {"actor": ..., "component": ..., "variable": ..., "value": ...}
              또는 {"error": "..."}
    """
    try:
        # 1) Actor 찾기
        target_actor = None
        try:
            actors = unreal.EditorLevelLibrary.get_all_level_actors()
            for a in actors:
                if a is not None and a.get_name() == actor_name:
                    target_actor = a
                    break
        except Exception:
            pass

        # PIE 모드에서 못 찾으면 게임 월드 검색
        if target_actor is None:
            try:
                game_world = unreal.EditorLevelLibrary.get_game_world()
                if game_world is not None:
                    actors = unreal.GameplayStatics.get_all_actors_of_class(game_world, unreal.Actor)
                    for a in actors:
                        if a is not None and a.get_name() == actor_name:
                            target_actor = a
                            break
            except Exception:
                pass

        if target_actor is None:
            return {"error": f"Actor not found: {actor_name}"}

        # 2) 컴포넌트 찾기
        target_component = None
        try:
            # 문자열로 된 클래스 이름을 unreal 클래스로 변환
            # 예: "SceneCaptureComponent2D" → unreal.SceneCaptureComponent2D
            component_class = getattr(unreal, component_class_name, None)
            if component_class is not None:
                target_component = target_actor.get_component_by_class(component_class)
        except Exception:
            pass

        if target_component is None:
            return {"error": f"Component not found: {component_class_name} on actor {actor_name}"}

        # 3) 변수/프로퍼티 읽기
        try:
            value = target_component.get_editor_property(variable_name)
        except Exception:
            try:
                value = getattr(target_component, variable_name, None)
            except Exception:
                value = None

        return {
            "actor": actor_name,
            "component": component_class_name,
            "variable": variable_name,
            "value": str(value) if value is not None else "None",
        }
    except Exception as e:
        return {"error": str(e)}


def set_component_variable(actor_name, component_class_name, variable_name, value):
    """Actor의 특정 컴포넌트의 변수를 쓴다.

    Args:
        actor_name (str): 액터의 내부 이름.
        component_class_name (str): 컴포넌트 클래스 이름.
        variable_name (str): 설정할 변수 이름.
        value: 설정할 값.

    Returns:
        dict: {"actor": ..., "component": ..., "variable": ..., "old_value": ..., "new_value": ...}
              또는 {"error": "..."}
    """
    try:
        # 1) Actor 찾기
        target_actor = None
        try:
            actors = unreal.EditorLevelLibrary.get_all_level_actors()
            for a in actors:
                if a is not None and a.get_name() == actor_name:
                    target_actor = a
                    break
        except Exception:
            pass

        # PIE 모드에서 못 찾으면 게임 월드 검색
        if target_actor is None:
            try:
                game_world = unreal.EditorLevelLibrary.get_game_world()
                if game_world is not None:
                    actors = unreal.GameplayStatics.get_all_actors_of_class(game_world, unreal.Actor)
                    for a in actors:
                        if a is not None and a.get_name() == actor_name:
                            target_actor = a
                            break
            except Exception:
                pass

        if target_actor is None:
            return {"error": f"Actor not found: {actor_name}"}

        # 2) 컴포넌트 찾기
        target_component = None
        try:
            component_class = getattr(unreal, component_class_name, None)
            if component_class is not None:
                target_component = target_actor.get_component_by_class(component_class)
        except Exception:
            pass

        if target_component is None:
            return {"error": f"Component not found: {component_class_name} on actor {actor_name}"}

        # 3) 이전 값 저장
        try:
            old_value = target_component.get_editor_property(variable_name)
        except Exception:
            old_value = None

        # 4) 변수/프로퍼티 쓰기
        try:
            target_component.set_editor_property(variable_name, value)
        except Exception:
            try:
                setattr(target_component, variable_name, value)
            except Exception as e:
                return {"error": f"Failed to set property: {e}"}

        # 5) 새 값 확인
        try:
            new_value = target_component.get_editor_property(variable_name)
        except Exception:
            new_value = None

        return {
            "actor": actor_name,
            "component": component_class_name,
            "variable": variable_name,
            "old_value": str(old_value) if old_value is not None else "None",
            "new_value": str(new_value) if new_value is not None else "None",
        }
    except Exception as e:
        return {"error": str(e)}
