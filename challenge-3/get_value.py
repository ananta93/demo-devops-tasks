class dict2obj(object):
    def __init__(self, d):
        self.__dict__['object'] = d

    def __getattr__(self, key):
        value = self.__dict__['object'][key]
        if type(value) == type({}):
            return dict2obj(value)
        return value

k1=input("Please input the first key: ") 
k2=input("Please input the second key: ") 
k3=input("Please input the third key: ") 
v2=input("Plesse input the value: ") 
object={k1:{k2:{k3:v2}}}

value3 = dict2obj(object)
print("The Value is: "+value3.a.b.c)