require 'concurrent'

class FdsTimer
  def initialize(timeout_ms, &task)
    @timeout = timeout_ms
    @timer_task = nil
    @task = task
  end

  def start()
    cancel_timer_task
    @timer_task = Concurrent::ScheduledTask.execute(@timeout/1000.0) do
      # 在这里执行你的定时任务逻辑
      @task.call
    end
    @timer_task.execute
  end

  def reset()
    @timer_task&.cancel
    start
  end

  def cancel_timer_task
    @timer_task&.cancel
  end
end