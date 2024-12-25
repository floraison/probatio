
#
# examples of probatio plugins

class MyProbatioPlugin

  def on_test_succeed(ev)

    puts "GREAT SUCCESS! " + ev.to_s
  end
end

Probatio.plug(MyProbatioPlugin.new)

