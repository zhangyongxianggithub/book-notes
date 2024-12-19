使用`Comparator`与`Comparable`接口来比较自定义类型。
# Comparable
定义了同类型对象的比较策略的接口，称为类的自然排序，natural ordering。排序类需要实现这个接口。个很久返回值决定顺序。
# Comparator
也是一个接口，定义了`compare(arg1,arg2)`方法，参数表示要比较的2个对象，
## 使用`Comparator.comparing`
- key function的形式
    ```java
    static <T,U extends Comparable<? super U>> Comparator<T> comparing(
    Function<? super T,? extends U> keyExtractor)
    ```
- Key Selector and Comparator Variant
  ```java
    @Test
    public void whenComparingWithComparator_thenSortedByNameDesc() {
        Comparator<Employee> employeeNameComparator
        = Comparator.comparing(
            Employee::getName, (s1, s2) -> {
                return s2.compareTo(s1);
            });
        
        Arrays.sort(employees, employeeNameComparator);
        
        assertTrue(Arrays.equals(employees, sortedEmployeesByNameDesc));
    }
  ```
- Comparator.reversed
  ```java
    @Test
    public void whenReversed_thenSortedByNameDesc() {
        Comparator<Employee> employeeNameComparator
        = Comparator.comparing(Employee::getName);
        Comparator<Employee> employeeNameComparatorReversed 
        = employeeNameComparator.reversed();
        Arrays.sort(employees, employeeNameComparatorReversed);
        assertTrue(Arrays.equals(employees, sortedEmployeesByNameDesc));
    }
  ```
- 使用`Comparator.comparingInt`
  ```java
    @Test
    public void whenComparingInt_thenSortedByAge() {
        Comparator<Employee> employeeAgeComparator 
        = Comparator.comparingInt(Employee::getAge);
        
        Arrays.sort(employees, employeeAgeComparator);
        
        assertTrue(Arrays.equals(employees, sortedEmployeesByAge));
    }
  ```
- 使用`Comparator.comparingLong`
- 使用`Comparator.comparingDouble`
- 使用`Comparator.natureOrder()`
- 使用`Comparator.reverseOrder`
- 
