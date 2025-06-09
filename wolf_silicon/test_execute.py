from env_vcs import WolfSiliconEnv



def test_execute_command_normal():
    print(">>> Test: Normal execution")
    cmd = "echo HelloWorld"
    output = WolfSiliconEnv.execute_command(cmd, 5)
    print(output)

def test_execute_command_timeout():
    print(">>> Test: Timeout")
    cmd = " ./playground/wksp_0607_134929/simv"
    #cmd = "echo 'Starting...' && sleep 2 && echo 'Finished'"
    output = WolfSiliconEnv.execute_command(cmd, 9)
    print(output)

def test_error ():
    print(">>> Test: error")
    cmd = "ls /non/existent/directory"
    output = WolfSiliconEnv.execute_command(cmd, 10)
    print(output)

if __name__ == "__main__":
    test_error()
    test_execute_command_normal()
    test_execute_command_timeout()
