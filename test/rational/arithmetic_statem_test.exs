defmodule Rational.ArithmeticStateMTest do
  use ExUnit.Case, async: false
  use PropCheck
  import PropCheck.StateM

  property "rational arithmetic StateM property", [:verbose, {:numtests, 100}, {:constraint_tries, 50}] do
    forall(cmds <- commands(Rational.ArithmeticStateM)) do
      {history, state, result} = run_commands(Rational.ArithmeticStateM, cmds)

      (result == :ok)
      |> aggregate(command_names(cmds))
      |> when_fail(print_failure_report(cmds, state, result, history))
    end
  end

  # property "rational arithmetic parallel StateM property", [:verbose, {:numtests, 100}, {:constraint_tries, 50}] do
  #   forall(cmds <- parallel_commands(Rational.ArithmeticStateM)) do
  #     {history, state, result} = run_parallel_commands(Rational.ArithmeticStateM, cmds)

  #     (result == :ok)
  #     |> aggregate(:proper_statem.zip(:proper_fsm.state_names(history), command_names(cmds)))
  #     |> when_fail(print_failure_report(cmds, state, result, history))
  #   end
  # end

  @doc false
  defp print_failure_report(cmds, state, result, history) do
    IO.puts(
      :io_lib.format(
        <<
          "=======~n",
          "Failing command sequence:~n~s~n",
          "At state: ~s~n",
          "=======~n",
          "Result: ~s~n",
          "History: ~s~n"
        >>,
        [
          inspect(cmds, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors)),
          inspect(state, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors)),
          inspect(result, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors)),
          inspect(history, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors))
        ]
      )
    )
  end
end
