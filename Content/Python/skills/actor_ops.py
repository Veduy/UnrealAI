"""
Actor Operations
================
레벨 내 액터 조회, 검색, 삭제, 트랜스폼 설정.
MCP의 get_actors_in_level / find_actors_by_name / delete_actor / set_actor_transform에 대응.
"""

import unreal
import fnmatch


def get_actors_in_level():
    """레벨 내 모든 액터 목록을 반환한다.

    Returns:
        dict: {"actors": [{"name": ..., "label": ..., "class": ..., "location": [...], "rotation": [...], "scale": [...]}, ...]}
    """
    try:
        actors = unreal.EditorLevelLibrary.get_all_level_actors()
        result = []
        for a in actors:
            if a is None:
                continue
            loc = a.get_actor_location()
            rot = a.get_actor_rotation()
            scale = a.get_actor_scale3d()
            result.append({
                "name": a.get_name(),
                "label": a.get_actor_label(),
                "class": a.get_class().get_name(),
                "location": [loc.x, loc.y, loc.z],
                "rotation": [rot.pitch, rot.yaw, rot.roll],
                "scale": [scale.x, scale.y, scale.z],
            })
        return {"actors": result}
    except Exception as e:
        return {"error": str(e)}


def find_actors_by_name(pattern):
    """이름 패턴으로 액터를 검색한다.

    C++ MCP는 단순 Contains 매칭을 사용하지만,
    여기서는 fnmatch 와일드카드도 지원한다.
    패턴에 *나 ?가 없으면 Contains 매칭으로 동작.

    Args:
        pattern (str): 검색 패턴. "Wall" → 이름에 Wall 포함. "Wall*" → fnmatch.

    Returns:
        dict: {"actors": [...]}
    """
    try:
        actors = unreal.EditorLevelLibrary.get_all_level_actors()
        use_glob = ("*" in pattern or "?" in pattern)
        result = []
        for a in actors:
            if a is None:
                continue
            name = a.get_name()
            matched = False
            if use_glob:
                matched = fnmatch.fnmatch(name, pattern)
            else:
                matched = pattern in name
            if matched:
                loc = a.get_actor_location()
                rot = a.get_actor_rotation()
                scale = a.get_actor_scale3d()
                result.append({
                    "name": name,
                    "label": a.get_actor_label(),
                    "class": a.get_class().get_name(),
                    "location": [loc.x, loc.y, loc.z],
                    "rotation": [rot.pitch, rot.yaw, rot.roll],
                    "scale": [scale.x, scale.y, scale.z],
                })
        return {"actors": result}
    except Exception as e:
        return {"error": str(e)}


def delete_actor(name):
    """이름으로 액터를 찾아 삭제한다.

    Args:
        name (str): 삭제할 액터의 내부 이름 (get_name() 결과).

    Returns:
        dict: {"deleted_actor": {...}} 또는 {"error": "..."}
    """
    try:
        actors = unreal.EditorLevelLibrary.get_all_level_actors()
        for a in actors:
            if a is None:
                continue
            if a.get_name() == name:
                loc = a.get_actor_location()
                info = {
                    "name": a.get_name(),
                    "label": a.get_actor_label(),
                    "class": a.get_class().get_name(),
                    "location": [loc.x, loc.y, loc.z],
                }
                a.destroy_actor()
                return {"deleted_actor": info}
        return {"error": f"Actor not found: {name}"}
    except Exception as e:
        return {"error": str(e)}


def set_actor_transform(name, location=None, rotation=None, scale=None):
    """액터의 트랜스폼(위치/회전/스케일)을 설정한다.

    Args:
        name (str): 액터의 내부 이름.
        location (list[float], optional): [x, y, z] 위치.
        rotation (list[float], optional): [pitch, yaw, roll] 회전.
        scale (list[float], optional): [x, y, z] 스케일.

    Returns:
        dict: 변경 후 트랜스폼 정보 또는 {"error": "..."}
    """
    try:
        actors = unreal.EditorLevelLibrary.get_all_level_actors()
        target = None
        for a in actors:
            if a is not None and a.get_name() == name:
                target = a
                break

        if target is None:
            return {"error": f"Actor not found: {name}"}

        if location is not None:
            target.set_actor_location(
                unreal.Vector(location[0], location[1], location[2]),
                False, False
            )

        if rotation is not None:
            target.set_actor_rotation(
                unreal.Rotator(rotation[0], rotation[1], rotation[2]),
                False
            )

        if scale is not None:
            target.set_actor_scale3d(
                unreal.Vector(scale[0], scale[1], scale[2])
            )

        loc = target.get_actor_location()
        rot = target.get_actor_rotation()
        sc = target.get_actor_scale3d()
        return {
            "name": target.get_name(),
            "label": target.get_actor_label(),
            "class": target.get_class().get_name(),
            "location": [loc.x, loc.y, loc.z],
            "rotation": [rot.pitch, rot.yaw, rot.roll],
            "scale": [sc.x, sc.y, sc.z],
        }
    except Exception as e:
        return {"error": str(e)}


def set_actor_variable(actor_name, variable_name, value):
    """레벨 내 액터의 변수(프로퍼티) 값을 설정한다.
    에디터 상태와 PIE(플레이) 상태를 모두 지원한다.

    Args:
        actor_name (str): 액터의 내부 이름 (get_name() 결과).
        variable_name (str): 설정할 변수 이름.
        value: 설정할 값 (bool, int, float, str 등).

    Returns:
        dict: {"actor": ..., "variable": ..., "old_value": ..., "new_value": ..., "context": "editor"|"game"}
              또는 {"error": "..."}
    """
    try:
        target = None
        context = "editor"

        # 0) PIE 모드 여부 확인
        is_pie = False
        try:
            game_world = unreal.EditorLevelLibrary.get_game_world()
            is_pie = game_world is not None
        except Exception:
            pass

        # 1) PIE 모드: 게임 월드에서 액터 검색
        if is_pie:
            try:
                actors = unreal.GameplayStatics.get_all_actors_of_class(game_world, unreal.Actor)
                for a in actors:
                    if a is not None and a.get_name() == actor_name:
                        target = a
                        context = "game"
                        break
            except Exception:
                pass

        # 2) 에디터 모드 또는 PIE에서 못 찾은 경우: 에디터 레벨에서 검색
        if target is None:
            try:
                actors = unreal.EditorLevelLibrary.get_all_level_actors()
                for a in actors:
                    if a is not None and a.get_name() == actor_name:
                        target = a
                        context = "editor"
                        break
            except Exception:
                pass

        if target is None:
            return {"error": f"Actor not found: {actor_name}"}

        try:
            old_value = target.get_editor_property(variable_name)
        except Exception:
            old_value = getattr(target, variable_name, None)

        # set_editor_property 먼저 시도, 실패하면 setattr로 fallback
        try:
            target.set_editor_property(variable_name, value)
        except Exception:
            setattr(target, variable_name, value)

        try:
            new_value = target.get_editor_property(variable_name)
        except Exception:
            new_value = getattr(target, variable_name, None)

        return {
            "actor": actor_name,
            "variable": variable_name,
            "old_value": str(old_value),
            "new_value": str(new_value),
            "context": context,
        }
    except Exception as e:
        return {"error": str(e)}
