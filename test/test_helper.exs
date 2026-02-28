Mox.defmock(Sunxi.FEL.MockExecutor, for: Sunxi.FEL.Executor)
Application.put_env(:sunxi, :executor, Sunxi.FEL.MockExecutor)

ExUnit.start()
