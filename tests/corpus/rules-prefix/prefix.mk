.RECIPEPREFIX = >
all: a
>@echo all 'a#b' a#b
>  @echo spaced
>
>@echo "[$(.RECIPEPREFIX)]"
a:
>@echo one \
>two \
	three
dry:
>echo four \
>>five \
	six
err:
>@true
>@exit 3
