defmodule TrafficWeb.Components.Road do
  def update(assigns, socket) do
    assigns = Surface.Component.restore_id(assigns)
    {:ok, Phoenix.LiveView.assign(socket, assigns)}
  end

  def render(assigns) do
    lane_count = :erlang.+(Enum.count(assigns.road.right), Enum.count(assigns.road.left))

    assigns =
      :maps.put(
        :lane_color,
        "#c0c0c0",
        :maps.put(
          :width,
          :erlang.*(assigns.road.length, 100),
          :maps.put(
            :height,
            :erlang.*(lane_count, :erlang.+(assigns.lane_width, 1)),
            :maps.put(
              :r_lanes,
              Enum.count(assigns.road.right),
              :maps.put(:l_lanes, Enum.count([]), assigns)
            )
          )
        )
      )

    (
      Phoenix.LiveView.Engine

      (
        dynamic = fn track_changes? ->
          changed =
            case(assigns) do
              %{__changed__: changed} when track_changes? ->
                changed

              _ ->
                nil
            end

          (
            arg0 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :width)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :width,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :width,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :width)],
                          [],
                          nil,
                          "@width"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg1 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :height)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :height,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :height,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :height)],
                          [],
                          nil,
                          "@height"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg2 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :width)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :x2,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :x2,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :width)],
                          [],
                          nil,
                          "@width"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg3 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :lane_color)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :stroke,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :stroke,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :lane_color)],
                          [],
                          nil,
                          "@lane_color"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            TrafficWeb.Components.Lane

            arg4 =
              case(
                case(Phoenix.LiveView.Engine.changed_assign?(changed, :width)) do
                  false ->
                    case(
                      Phoenix.LiveView.Engine.nested_changed_assign?(assigns, changed, :road,
                        struct: :right
                      )
                    ) do
                      false ->
                        case(
                          Phoenix.LiveView.Engine.nested_changed_assign?(assigns, changed, :road,
                            struct: :name
                          )
                        ) do
                          false ->
                            case(
                              Phoenix.LiveView.Engine.nested_changed_assign?(
                                assigns,
                                changed,
                                :road,
                                struct: :length
                              )
                            ) do
                              false ->
                                case(
                                  Phoenix.LiveView.Engine.changed_assign?(changed, :lane_width)
                                ) do
                                  false ->
                                    Phoenix.LiveView.Engine.changed_assign?(changed, :__context__)

                                  true ->
                                    true

                                  other ->
                                    :erlang.error({:badbool, :or, other})
                                end

                              true ->
                                true

                              other ->
                                :erlang.error({:badbool, :or, other})
                            end

                          true ->
                            true

                          other ->
                            :erlang.error({:badbool, :or, other})
                        end

                      true ->
                        true

                      other ->
                        :erlang.error({:badbool, :or, other})
                    end

                  true ->
                    true

                  other ->
                    :erlang.error({:badbool, :or, other})
                end
              ) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.LiveView.Helpers.__live_component__(
                      TrafficWeb.Components.Lane.__live__(),
                      Surface.build_assigns(
                        Phoenix.LiveView.Engine.fetch_assign!(assigns, :__context__),
                        [
                          id:
                            Surface.TypeHandler.expr_to_value!(
                              :string,
                              :id,
                              [
                                <<:erlang.atom_to_binary(
                                    Phoenix.LiveView.Engine.fetch_assign!(assigns, :road).name,
                                    :utf8
                                  )::binary(), "right">>
                              ],
                              [],
                              TrafficWeb.Components.Lane,
                              "Atom.to_string(@road.name) <> \"right\" "
                            ),
                          width:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :width,
                              [Phoenix.LiveView.Engine.fetch_assign!(assigns, :width)],
                              [],
                              TrafficWeb.Components.Lane,
                              "@width"
                            ),
                          road_length:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :road_length,
                              [Phoenix.LiveView.Engine.fetch_assign!(assigns, :road).length],
                              [],
                              TrafficWeb.Components.Lane,
                              "@road.length"
                            ),
                          lane_width:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :lane_width,
                              [Phoenix.LiveView.Engine.fetch_assign!(assigns, :lane_width)],
                              [],
                              TrafficWeb.Components.Lane,
                              "@lane_width"
                            ),
                          flip: true,
                          lanes:
                            case(Phoenix.LiveView.Engine.fetch_assign!(assigns, :road).right) do
                              value
                              when :erlang.orelse(
                                     :erlang.is_list(value),
                                     :erlang.andalso(
                                       :erlang.andalso(
                                         :erlang.andalso(
                                           :erlang.is_map(value),
                                           :erlang.orelse(:erlang.is_atom(Range), :fail)
                                         ),
                                         :erlang.is_map_key(:__struct__, value)
                                       ),
                                       :erlang.==(:erlang.map_get(:__struct__, value), Range)
                                     )
                                   ) ->
                                Enum.to_list(value)

                              value ->
                                :erlang.error(
                                  RuntimeError.exception(
                                    <<"invalid value for property \"",
                                      String.Chars.to_string(:lanes)::binary(),
                                      "\". Expected a :list, got: ",
                                      Kernel.inspect(value)::binary()>>
                                  )
                                )
                            end,
                          offset:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :offset,
                              [0],
                              [],
                              TrafficWeb.Components.Lane,
                              "0"
                            )
                        ],
                        [],
                        [],
                        [default: %{size: 0}],
                        TrafficWeb.Components.Lane,
                        "Lane"
                      ),
                      nil
                    )
                  )

                false ->
                  nil
              end

            arg5 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :r_lanes)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :y1,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :y1,
                          [
                            :erlang.*(
                              Phoenix.LiveView.Engine.fetch_assign!(assigns, :r_lanes),
                              TrafficWeb.Components.Lane.lane_width()
                            )
                          ],
                          [],
                          nil,
                          "@r_lanes * Lane.lane_width()"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg6 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :width)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :x2,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :x2,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :width)],
                          [],
                          nil,
                          "@width"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg7 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :r_lanes)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :y2,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :y2,
                          [
                            :erlang.*(
                              Phoenix.LiveView.Engine.fetch_assign!(assigns, :r_lanes),
                              TrafficWeb.Components.Lane.lane_width()
                            )
                          ],
                          [],
                          nil,
                          "@r_lanes * Lane.lane_width()"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg8 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :lane_color)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :stroke,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :stroke,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :lane_color)],
                          [],
                          nil,
                          "@lane_color"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            TrafficWeb.Components.Lane

            arg9 =
              case(
                case(Phoenix.LiveView.Engine.changed_assign?(changed, :width)) do
                  false ->
                    case(
                      Phoenix.LiveView.Engine.nested_changed_assign?(assigns, changed, :road,
                        struct: :name
                      )
                    ) do
                      false ->
                        case(
                          Phoenix.LiveView.Engine.nested_changed_assign?(assigns, changed, :road,
                            struct: :length
                          )
                        ) do
                          false ->
                            case(
                              Phoenix.LiveView.Engine.nested_changed_assign?(
                                assigns,
                                changed,
                                :road,
                                struct: :left
                              )
                            ) do
                              false ->
                                case(
                                  Phoenix.LiveView.Engine.changed_assign?(changed, :r_lanes)
                                ) do
                                  false ->
                                    case(
                                      Phoenix.LiveView.Engine.changed_assign?(
                                        changed,
                                        :lane_width
                                      )
                                    ) do
                                      false ->
                                        Phoenix.LiveView.Engine.changed_assign?(
                                          changed,
                                          :__context__
                                        )

                                      true ->
                                        true

                                      other ->
                                        :erlang.error({:badbool, :or, other})
                                    end

                                  true ->
                                    true

                                  other ->
                                    :erlang.error({:badbool, :or, other})
                                end

                              true ->
                                true

                              other ->
                                :erlang.error({:badbool, :or, other})
                            end

                          true ->
                            true

                          other ->
                            :erlang.error({:badbool, :or, other})
                        end

                      true ->
                        true

                      other ->
                        :erlang.error({:badbool, :or, other})
                    end

                  true ->
                    true

                  other ->
                    :erlang.error({:badbool, :or, other})
                end
              ) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.LiveView.Helpers.__live_component__(
                      TrafficWeb.Components.Lane.__live__(),
                      Surface.build_assigns(
                        Phoenix.LiveView.Engine.fetch_assign!(assigns, :__context__),
                        [
                          width:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :width,
                              [Phoenix.LiveView.Engine.fetch_assign!(assigns, :width)],
                              [],
                              TrafficWeb.Components.Lane,
                              "@width"
                            ),
                          road_length:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :road_length,
                              [Phoenix.LiveView.Engine.fetch_assign!(assigns, :road).length],
                              [],
                              TrafficWeb.Components.Lane,
                              "@road.length"
                            ),
                          lanes:
                            case(Phoenix.LiveView.Engine.fetch_assign!(assigns, :road).left) do
                              value
                              when :erlang.orelse(
                                     :erlang.is_list(value),
                                     :erlang.andalso(
                                       :erlang.andalso(
                                         :erlang.andalso(
                                           :erlang.is_map(value),
                                           :erlang.orelse(:erlang.is_atom(Range), :fail)
                                         ),
                                         :erlang.is_map_key(:__struct__, value)
                                       ),
                                       :erlang.==(:erlang.map_get(:__struct__, value), Range)
                                     )
                                   ) ->
                                Enum.to_list(value)

                              value ->
                                :erlang.error(
                                  RuntimeError.exception(
                                    <<"invalid value for property \"",
                                      String.Chars.to_string(:lanes)::binary(),
                                      "\". Expected a :list, got: ",
                                      Kernel.inspect(value)::binary()>>
                                  )
                                )
                            end,
                          lane_width:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :lane_width,
                              [Phoenix.LiveView.Engine.fetch_assign!(assigns, :lane_width)],
                              [],
                              TrafficWeb.Components.Lane,
                              "@lane_width"
                            ),
                          id:
                            Surface.TypeHandler.expr_to_value!(
                              :string,
                              :id,
                              [
                                <<:erlang.atom_to_binary(
                                    Phoenix.LiveView.Engine.fetch_assign!(assigns, :road).name,
                                    :utf8
                                  )::binary(), "left">>
                              ],
                              [],
                              TrafficWeb.Components.Lane,
                              "Atom.to_string(@road.name) <> \"left\" "
                            ),
                          offset:
                            Surface.TypeHandler.expr_to_value!(
                              :integer,
                              :offset,
                              [
                                :erlang.*(
                                  Phoenix.LiveView.Engine.fetch_assign!(assigns, :r_lanes),
                                  :erlang.+(TrafficWeb.Components.Lane.lane_width(), 1)
                                )
                              ],
                              [],
                              TrafficWeb.Components.Lane,
                              "@r_lanes * (Lane.lane_width() + 1)"
                            )
                        ],
                        [],
                        [],
                        [default: %{size: 0}],
                        TrafficWeb.Components.Lane,
                        "Lane"
                      ),
                      nil
                    )
                  )

                false ->
                  nil
              end

            arg10 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :height)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :y1,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :y1,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :height)],
                          [],
                          nil,
                          "@height"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg11 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :width)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :x2,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :x2,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :width)],
                          [],
                          nil,
                          "@width"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg12 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :height)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :y2,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :y2,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :height)],
                          [],
                          nil,
                          "@height"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end

            arg13 =
              case(Phoenix.LiveView.Engine.changed_assign?(changed, :lane_color)) do
                true ->
                  Phoenix.LiveView.Engine.live_to_iodata(
                    Phoenix.HTML.raw(
                      Surface.TypeHandler.attr_to_html!(
                        :string,
                        :stroke,
                        Surface.TypeHandler.expr_to_value!(
                          :string,
                          :stroke,
                          [Phoenix.LiveView.Engine.fetch_assign!(assigns, :lane_color)],
                          [],
                          nil,
                          "@lane_color"
                        )
                      )
                    )
                  )

                false ->
                  nil
              end
          )

          [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13]
        end

        %Phoenix.LiveView.Rendered{
          static: [
            "<g",
            "",
            " version=\"1.1\">\n  <line x1=\"0\" y1=\"0\"",
            " y2=\"0\"",
            " stroke-width=\"5\"></line>\n\n  \n  ",
            "\n  <line x1=\"0\"",
            "",
            "",
            "",
            " stroke-width=\"2.5\"></line>\n  ",
            "\n\n  <line x1=\"0\"",
            "",
            "",
            "",
            " stroke-width=\"5\"></line>\n</g>\n"
          ],
          dynamic: dynamic,
          fingerprint: 29_139_549_897_258_702_812_649_054_021_403_565_958,
          root: nil
        }
      )
    )
  end

  def mount(socket) do
    {:ok, Surface.init(socket)}
  end

  def component_type() do
    Surface.Component
  end

  def __validate_slot__(prop) do
    :erlang."=:="(prop, :default)
  end

  def __validate_prop__(prop) do
    :erlang.orelse(
      :erlang.orelse(:erlang."=:="(prop, :class), :erlang."=:="(prop, :road)),
      :erlang."=:="(prop, :lane_width)
    )
  end

  def __slots__() do
    [%{doc: nil, func: :slot, line: 11, name: :default, opts: [], opts_ast: [], type: :any}]
  end

  def __required_slots_names__() do
    []
  end

  def __required_props_names__() do
    []
  end

  def __renderless__?() do
    false
  end

  def __props__() do
    [
      %{
        doc: nil,
        func: :prop,
        line: 6,
        name: :class,
        opts: [default: "items-center"],
        opts_ast: [default: "items-center"],
        type: :string
      },
      %{doc: nil, func: :prop, line: 7, name: :road, opts: [], opts_ast: [], type: :map},
      %{doc: nil, func: :prop, line: 9, name: :lane_width, opts: [], opts_ast: [], type: :integer}
    ]
  end

  def __live__() do
    %{kind: :component, module: TrafficWeb.Components.Road}
  end

  def __gets_context__?() do
    false
  end

  def __get_slot__(name) do
    Map.get(
      %{
        default: %{
          doc: nil,
          func: :slot,
          line: 11,
          name: :default,
          opts: [],
          opts_ast: [],
          type: :any
        }
      },
      name
    )
  end

  def __get_prop__(name) do
    Map.get(
      %{
        class: %{
          doc: nil,
          func: :prop,
          line: 6,
          name: :class,
          opts: [default: "items-center"],
          opts_ast: [default: "items-center"],
          type: :string
        },
        lane_width: %{
          doc: nil,
          func: :prop,
          line: 9,
          name: :lane_width,
          opts: [],
          opts_ast: [],
          type: :integer
        },
        road: %{doc: nil, func: :prop, line: 7, name: :road, opts: [], opts_ast: [], type: :map}
      },
      name
    )
  end

  def __data__() do
    [
      %{doc: nil, func: :data, line: 8, name: :width, opts: [], opts_ast: [], type: :integer},
      %{
        doc: "Built-in assign",
        func: :data,
        line: 2,
        name: :inner_block,
        opts: [],
        opts_ast: [],
        type: :fun
      },
      %{
        doc: "Built-in assign",
        func: :data,
        line: 2,
        name: :socket,
        opts: [],
        opts_ast: [],
        type: :struct
      }
    ]
  end

  def __changes_context__?() do
    false
  end

  def __assigned_slots_by_parent__() do
    %{}
  end
end