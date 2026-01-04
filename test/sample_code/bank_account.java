// Bank Account Management System
// Demonstrates Java class structure, inheritance, and methods

package com.example.banking;

/**
 * Represents a basic bank account
 * Supports deposit and withdrawal operations
 */
public class BankAccount {
    private String accountNumber;
    private double balance;
    private String accountHolder;
    
    /**
     * Constructor for BankAccount
     * @param accountNumber The unique account identifier
     * @param accountHolder Name of the account holder
     * @param initialBalance Starting balance amount
     */
    public BankAccount(String accountNumber, String accountHolder, double initialBalance) {
        this.accountNumber = accountNumber;
        this.accountHolder = accountHolder;
        this.balance = initialBalance;
    }
    
    /**
     * Deposits money into the account
     * @param amount Amount to deposit
     * @return true if deposit successful, false otherwise
     */
    public boolean deposit(double amount) {
        if (amount > 0) {
            balance += amount;
            return true;
        }
        return false;
    }
    
    /**
     * Withdraws money from the account
     * @param amount Amount to withdraw
     * @return true if withdrawal successful, false otherwise
     */
    public boolean withdraw(double amount) {
        if (amount > 0 && amount <= balance) {
            balance -= amount;
            return true;
        }
        return false;
    }
    
    /**
     * Gets the current balance
     * @return Current account balance
     */
    public double getBalance() {
        return balance;
    }
    
    /**
     * Gets the account number
     * @return Account number
     */
    public String getAccountNumber() {
        return accountNumber;
    }
}

/**
 * Savings account with interest functionality
 * Extends BankAccount to add interest calculation
 */
class SavingsAccount extends BankAccount {
    private double interestRate;
    
    /**
     * Constructor for SavingsAccount
     * @param accountNumber Account identifier
     * @param accountHolder Account holder name
     * @param initialBalance Starting balance
     * @param interestRate Annual interest rate
     */
    public SavingsAccount(String accountNumber, String accountHolder, double initialBalance, double interestRate) {
        super(accountNumber, accountHolder, initialBalance);
        this.interestRate = interestRate;
    }
    
    /**
     * Calculates and adds interest to the account
     */
    public void addInterest() {
        double interest = getBalance() * interestRate / 100;
        deposit(interest);
    }
    
    /**
     * Gets the interest rate
     * @return Current interest rate
     */
    public double getInterestRate() {
        return interestRate;
    }
}