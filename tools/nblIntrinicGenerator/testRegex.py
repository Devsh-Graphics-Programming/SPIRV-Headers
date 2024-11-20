import re


items = ["[[ns::something_ext_blah_blah<W,uint32_t>]] const ptr_T&",
         "uint32_t",
         "const P&",
         "X",
         "2L"
         "L2"
         ]
expectedResult = [
    (["W"]),
    ([]),
    (["P"]),
    (["X"]),
    ([]),
    ([]),
]


query = "((?<![\w\d_])[A-Z])(?![\w\d_])"
q = re.compile(query)
for x in range(len(items)):
    found = q.findall(items[x])
    if found != expectedResult[x]:
        print(f"Different: {found} {expectedResult[x]}")
